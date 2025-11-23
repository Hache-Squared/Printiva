using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class RecetaProductoViewModel
    {
        // Datos de la Receta
        public int RecetaId { get; set; }

        [Display(Name = "Nombre de la Receta")] // Ejemplo de anotación para la UI
        public string Nombre { get; set; }

        [Display(Name = "Tiempo de Impresión")]
        public string TiempoImpresion { get; set; }

        // Datos del Producto
        public string ProductoNombre { get; set; }
        public string ProductoSKU { get; set; }

        // Datos de la Categoría
        public string ProductoCategoria { get; set; }
    }
}

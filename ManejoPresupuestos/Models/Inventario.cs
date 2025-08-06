using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Inventario
    {
        public int InventarioId { get; set; }

        [Display(Name = "Marca")]
        public int InventarioMarcaId { get; set; }

        [Display(Name = "Tipo de inventario")]
        public int InventarioTipoId { get; set; }

        [Display(Name = "Nombre")]
        public int InventarioNombreId { get; set; }

        [Display(Name = "Color")]
        public int InventarioColorId { get; set; }

        [Display(Name = "Unidad de medida (Conteo por gramos o por unidades)")]
        public int InventarioUnidadId { get; set; }
        public decimal Cantidad { get; set; }

        [Display(Name = "Fecha Creación")]
        [DataType(DataType.Date)]
        public DateTime FechaCreacion { get; set; } = DateTime.Today;
        public string InventarioMarca { get; set; }
        public string InventarioTipo { get; set; }
        public string InventarioNombre { get; set; }
        public string InventarioNombreAbreviatura { get; set; }
        public string InventarioColor { get; set; }
        public string InventarioColorAbreviatura { get; set; }
        public string InventarioUnidad { get; set; }
    }
}
